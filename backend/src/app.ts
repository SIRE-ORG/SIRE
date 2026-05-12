import Fastify from 'fastify';
import { userRoutes } from './routes/user.routes.js';

const app = Fastify({ logger: true });

app.register(userRoutes, { prefix: '/api/v1/users' });

const start = async () => {
    try {
        await app.listen({ port: 3000, host: '0.0.0.0' });
        console.log('SIRE Backend corriendo en http://localhost:3000');
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};

start();