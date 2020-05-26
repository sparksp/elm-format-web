import express from 'express';
import stripAnsi from 'strip-ansi';
import { exec, execSync } from 'child_process'

const app = express();
export const router = express.Router();

app.use(express.text());

router.get('/', (req, res) => {
    res.format({
        'text/plain': () => {
            res.send('elm-format!');
        },
        'text/html': () => {
            res.sendFile('index.html', { root: __dirname });
        },
        default: () => {
            res.status(406).send();
        }
    });
});

router.post('/', (req, res) => {
    res.format({
        text: () => {
            try {
                const stdout = execSync('elm-format --stdin', {
                    input: req.body,
                });
                res.send(stdout);
            }
            catch (e) {
                if (e.stdout.length > 0) {
                    res.status(400).send(e.stdout);
                }
                else {
                    const stderr = stripAnsi( e.stderr.toString() ).split('\n').slice(1);

                    if (stderr[0].startsWith('-- SYNTAX PROBLEM')) {
                        stderr[0] = stderr[0].replace(' <STDIN>', '--------');
                        res.status(400).send(stderr.join('\n'));
                    }
                    else {
                        res.status(500).send();
                    }
                }
            }
        },
        default: () => {
            res.status(406).send();
        }
    })
});

router.post('/validate', (req, res) => {
    res.format({
        text: () => {
            try {
                execSync('elm-format --validate --stdin', {
                    input: req.body,
                });
                res.send();
            }
            catch (e) {
                if (e.stdout.length > 0) {
                    const result = JSON.parse(e.stdout.toString());
                    res.status(400).send(result[0].message);
                } else {
                    const stderr = e.stderr.toString();
                    // tslint:disable-next-line:no-console
                    console.error(stderr);
                    res.status(500).send(stderr.split('\n')[0]);
                }
            }
        },
        json: () => {
            try {
                const stdout = execSync('elm-format --validate --stdin', {
                    input: req.body,
                });
                res.send(stdout);
            }
            catch (e) {
                if (e.stdout.length > 0) {
                    const result = JSON.parse(e.stdout.toString());
                    res.status(400).json(result);
                } else {
                    const stderr = e.stderr.toString();
                    // tslint:disable-next-line:no-console
                    console.error(stderr);
                    res.status(500).send({ error : stderr.split('\n')[0] });
                }
            }
        },
        default: () => {
            res.status(406).send();
        }
    })
});

router.get('/version', (req, res) => {
    res.format({
        'text/plain': () => {
            try {
                const stdout = execSync('elm-format').toString();
                res.send(stdout.split('\n')[0]);
            }
            catch (e) {
                if (e.stdout.length > 0) {
                    const stdout = e.stdout.toString();
                    res.send(stdout.split('\n')[0]);
                }
                else {
                    const stderr = e.stderr.toString();
                    // tslint:disable-next-line:no-console
                    console.error(stderr);
                    res.status(500).send(stderr.split('\n')[0]);
                }
            }
        },
        default: () => {
            res.status(406).send();
        }
    });
});

app.use(router);

export default app;