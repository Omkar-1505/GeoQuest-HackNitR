import ImageKit from "imagekit";
import { GoogleGenAI } from "@google/genai"; 
import { PrismaClient } from "../generated/prisma/client";

export const imagekit = new ImageKit({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY!,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY!,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT!,
});
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY! });

const prisma = new PrismaClient();


export default prisma;
