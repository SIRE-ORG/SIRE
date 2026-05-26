import Fastify from 'fastify';
import { publicationRoutes } from './routes/publication.routes.js';
import { authRoutes } from './routes/auth.routes.js';


const app = Fastify({
    logger: true,
    ignoreTrailingSlash: true
});

app.get('/', async (request, reply) => {
    return reply.redirect('/api/v1/publications');
});

app.register(authRoutes, { prefix: '/api/v1/auth' });
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