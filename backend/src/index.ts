import express,{ Express } from "express";
import cors from "cors"
import cookieParser from "cookie-parser";
import { env } from "./config/env";
const app:Express = express();

const PORT = env.PORT;

app.use(cors({origin:true,credentials:true}));
app.use(express.json());
app.use(cookieParser());


app.get("/health", (_, res) => {
  res.json({ status: "ok" });
});

app.use((req, res, next) => {
  console.log(`Incoming Request: ${req.method} ${req.url}`);
  next(); // Pass control to the next handler
});


app.listen(PORT,()=>{
    console.log(`Server starting at - http://localhost:${PORT}`);
    
})

