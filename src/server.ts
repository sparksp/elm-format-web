import dotenv from 'dotenv';
import app from './index';

dotenv.config();

const port = process.env.SERVER_PORT || 3000;

app.listen(port, () => {
    // tslint:disable-next-line:no-console
    console.log(`server started at http://localhost:${port}`);
});