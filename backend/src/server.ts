import express, { Request, Response } from "express";
import { User } from "./eums";

const app = express();
const port = 3000;

app.get("/api/test", (req: Request, res: Response) => {
    const user: User = {
        id: "123",
        name: "Hello World",
    };

    res.json({ message: "API Work with TypeScript 🚀", data: user });
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
