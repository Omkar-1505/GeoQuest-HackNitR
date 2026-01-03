import { Request, Response } from "express";
import { asyncHandler } from "../utils/handler";
import { ai, imagekit, prompt } from "../config/Configs";

export const AnalyzeAndUpload = asyncHandler(
  async (req: Request, res: Response) => {
    const file = req.file;
    const { latitude, longitude } = req.body;

    if (!file) {
      console.log("File not found nigga");

      return res.status(400).json({ error: "No image provided" });
    }

    console.log("Uploading the image lil nigga");

    let mimeType = file.mimetype;
    if (mimeType === "application/octet-stream") {
      mimeType = "image/jpeg"; // Assume JPEG for mobile camera uploads
    }

    const uploadPromise = imagekit.upload({
      file: file.buffer,
      fileName: `geo_${Date.now()}_${`gojogourav`}.jpg`, //(req.user as any)?.username
      folder: "/geoquest/discoveries",
    });

    const analysisPromise = (async () => {
      console.log("analyzing image lil niggaa");

      const modelId = "gemini-flash-lite-latest";

      const response = await ai.models.generateContent({
        model: modelId,
        contents: [
          {
            role: "user",
            parts: [
              {
                inlineData: {
                  mimeType: mimeType,
                  data: file.buffer.toString("base64"),
                },
              },
              {
                text: prompt,
              },
            ],
          },
        ],
        config: {
          responseMimeType: "application/json",
        },
      });

      const jsonText =
        response.text ||
        response.candidates?.[0]?.content?.parts?.[0]?.text ||
        "{}";
      console.log(jsonText);

      return JSON.parse(jsonText || "{}");
    })();

    const [uploadResult, aiResult] = await Promise.all([
      uploadPromise,
      analysisPromise,
    ]);
    if (!aiResult.isPlant || aiResult.confidence < 0.6) {
      return res.status(400).json({
        error: "Could not identify a plant. Please try again.",
        details: aiResult,
      });
    }

    return res.status(200).json({
      message: "Discovery Successful!",
      image_url: uploadResult.url,
      plant_data: aiResult,
    });

    
  }
);
