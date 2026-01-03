import { Router } from "express";
import multer from "multer"


const discoveryRouter:Router = Router();

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } // Limit to 5MB
});

discoveryRouter.post(
  "/scan", 
//   verifyToken,      
  upload.single("photo"),
  AnalyzeAndUpload   
);

export default discoveryRouter;