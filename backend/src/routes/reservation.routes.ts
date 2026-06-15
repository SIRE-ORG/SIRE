import type { FastifyInstance } from 'fastify';
import {
    createReservation,
    getMyReservations,
    updateReservationStatus,
    cancelReservation
} from '../controllers/reservation.controller.js';

export async function reservationRoutes(app: FastifyInstance) {
    app.post('/', createReservation);
    app.get('/mine', getMyReservations);
    app.patch('/:id/status', updateReservationStatus);
    app.delete('/:id', cancelReservation);
}
