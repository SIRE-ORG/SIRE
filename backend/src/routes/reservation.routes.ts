import type { FastifyInstance } from 'fastify';
import {
    createReservation,
    getMyReservations,
    getReceivedReservations,
    getReservationById,
    updateReservationStatus,
    cancelReservation
} from '../controllers/reservation.controller.js';

export async function reservationRoutes(app: FastifyInstance) {
    app.post('/', createReservation);
    app.get('/mine', getMyReservations);
    app.get('/received', getReceivedReservations);
    // /:id debe ir después de rutas fijas para que Fastify no capture "mine"/"received" como :id
    app.get('/:id', getReservationById);
    app.patch('/:id/status', updateReservationStatus);
    app.patch('/:id/cancel', cancelReservation);
}
