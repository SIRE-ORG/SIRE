import type { FastifyInstance } from 'fastify';
import { createReservation, getMyReservations } from '../controllers/reservation.controller.js';

export async function reservationRoutes(app: FastifyInstance) {
    app.post('/', createReservation);

    app.get('/mine', getMyReservations);
}