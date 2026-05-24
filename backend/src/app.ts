import Fastify from 'fastify';
import { userRoutes } from './routes/user.routes.js';
import { publicationRoutes } from './routes/publication.routes.js';

const app = Fastify({ logger: true });

app.register(userRoutes, { prefix: '/api/v1/users' });
app.register(publicationRoutes, { prefix: '/api/v1/publications' });

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