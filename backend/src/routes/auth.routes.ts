import express, { Request, Response, Router } from "express";
import { loginSchema, registerSchema } from "../utils/auth_schema";
import { validate } from "../middleware/type_validation";
import { Login_Controller, Register_Controller } from "../controller/auth_controller";


const AuthRouter:Router = express.Router();

AuthRouter.route("/login")
  .post(validate(loginSchema),Login_Controller);


AuthRouter.route("/register")
    .post(validate(registerSchema),Register_Controller)




export default AuthRouter;
