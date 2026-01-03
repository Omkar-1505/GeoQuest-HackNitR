import { Request, Response } from "express";
import { asyncHandler } from "../utils/handler";
import { ai, imagekit } from "../config/Configs";
import prisma from "../config/Configs";
import { getWeatherContext } from "../utils/weather.helper";

export const verifyDailyCare = asyncHandler(
  async (req: Request, res: Response) => {
    const file = req.file;
    const userId = (req as any).user?.uid;
    // taskId is optional (e.g., if they just want to post a status update)
    const { plantId, taskId } = req.body;

    if (!file || !plantId || !userId) {
      return res.status(400).json({ error: "Photo and Plant ID required" });
    }

    const plant = await prisma.plant.findUnique({
        where: { id: plantId },
        select: { latitude: true, longitude: true, healthScore: true }
    });

    if (!plant) return res.status(404).json({ error: "Plant not found" });

    const [historyLogs, weatherContext] = await Promise.all([
        prisma.careLog.findMany({
            where: { plantId: plantId },
            orderBy: { createdAt: 'desc' },
            take: 3,
            select: { action: true, createdAt: true }
        }),
        getWeatherContext(plant.latitude, plant.longitude)
    ]);

    const historyText = historyLogs.length > 0 
      ? historyLogs.map(log => `- ${log.action} on ${new Date(log.createdAt).toLocaleDateString()}`).join("\n")
      : "No previous care history.";
    
      console.log(`📜 Plant History:\n${historyText}`);

    const upload = await imagekit.upload({
      file: file.buffer,
      fileName: `care_${plantId}_${Date.now()}.jpg`,
      folder: "/geoquest/care_logs",
    });
    

    //  https://api.openweathermap.org/data/2.5/weather?lat=44.34&lon=10.99&appid={API key} 

    const checkupPrompt = `
    Analyze this plant photo strictly as a Botanist.
    
    CONTEXT:
    The user has provided this recent care history for this plant:
    ${historyText}

    - Current Local Weather: ${weatherContext}
    
    TASKS:
    1. Estimate Health Score looking at leaves (0-100).
    2. Give a 1-sentence status update based on visual health AND history.
       (Example: "Plant looks healthy, good job watering yesterday!" OR "Soil looks dry despite history, check drainage.")
    3. Give a specific care tip. If the user watered recently and it looks wet, warn them.
    
    Return JSON exactly: 
    { 
      "healthScore": 90, 
      "status": "Looking hydrated and happy!",
      "tip": "Since you watered yesterday, let the soil dry out for 2 more days."
    }
  `;

    const modelId = "gemini-flash-lite-latest";

    const response = await ai.models.generateContent({
      model: modelId,
      contents: [
        {
          role: "user",
          parts: [
            {
              inlineData: {
                mimeType: file.mimetype || "image/jpeg",
                data: file.buffer.toString("base64"),
              },
            },
            { text: checkupPrompt },
          ],
        },
      ],
      config: { responseMimeType: "application/json" },
    });

    const jsonText =
      response.text ||
      response.candidates?.[0]?.content?.parts?.[0]?.text ||
      "{}";
    const healthData = JSON.parse(jsonText);

    await prisma.$transaction(async (tx) => {
      await tx.plant.update({
        where: { id: plantId },
        data: { healthScore: healthData.healthScore },
      });

      if (taskId) {
        const task = await tx.careTask.findUnique({ where: { id: taskId } });
        if (task) {
          // Calculate next due date
          const nextDate = new Date();
          nextDate.setDate(nextDate.getDate() + task.frequencyDays);

          await tx.careTask.update({
            where: { id: taskId },
            data: {
              lastCompletedAt: new Date(),
              nextDueAt: nextDate,
            },
          });
        }
      }

      await tx.careLog.create({
        data: {
          userId,
          plantId,
          action: taskId ? "TASK_COMPLETE" : "DAILY_CHECKIN",
          photoUrl: upload.url,
          locationVerified: true,
        },
      });

      const xpReward = taskId ? 50 : 20;
      await tx.user.update({
        where: { id: userId },
        data: { xp: { increment: xpReward } },
      });
    });

    res.json({
      message: "Care Verified!",
      health_update: healthData.status,
      xp_gained: taskId ? 50 : 20,
    });
  }
);
