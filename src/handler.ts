'use strict';
import express from 'express';
import serverless from 'serverless-http';
import { router } from './index';

const app = express();
app.use('/.netlify/functions/server', router);

export default app;
export const handler = serverless(app);