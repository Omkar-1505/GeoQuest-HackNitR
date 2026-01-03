import { NextFunction, Request, Response } from "express";
import { Schema, ZodError, ZodObject } from "zod";

export const validate = (schema:ZodObject)=>async(req:Request,res:Response,next:NextFunction)=>{
     try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      console.log("succesful parsed ");
      next();
    }catch(error){
        if(error instanceof ZodError){
            return next(error);
        }
    }
}