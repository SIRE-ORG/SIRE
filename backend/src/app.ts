import Fastify from 'fastify';
import { userRoutes } from './routes/user.routes.js';
import { authRoutes } from './routes/auth.routes.js';
import { publicationRoutes } from './routes/publication.routes.js';
import { reservationRoutes } from './routes/reservation.routes.js';
import { notificationRoutes } from './routes/notification.routes.js';
import cors from '@fastify/cors';

const app = Fastify({ logger: true });
const port = process.env.PORT ? Number.parseInt(process.env.PORT, 10) : 3000;

app.register(cors, { origin: true });
app.register(userRoutes, { prefix: '/api/v1/users' });
app.register(authRoutes, { prefix: '/api/v1/auth' });
app.register(publicationRoutes, { prefix: '/api/v1/publications' });
app.register(reservationRoutes, { prefix: '/api/v1/reservations' });
app.register(notificationRoutes, { prefix: '/api/v1/notifications' });

const start = async () => {
    try {
        const address = await app.listen({
            port: port,
            host: '0.0.0.0'
        });
        console.log(`Servidor escuchando en ${address}`);
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};
start();
