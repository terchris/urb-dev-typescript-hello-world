/*
file: app/index.ts
This is a basic web server using Express and TypeScript
It serves a simple "Hello world" message on the root URL
It is a simple example to demonstrate how to set up a TypeScript project with Express
and how to run a basic web server
*/
import express from 'express';

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_, res) => {
  res.send('Hello world from typescript-basic-webserver');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
