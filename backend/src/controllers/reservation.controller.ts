import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient, ReservationStatus } from '@prisma/client';

const prisma = new PrismaClient();

// POST /api/v1/reservations -> Crear solicitud de reserva
export const createReservation = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { publicationId, date, startTime, endTime } = request.body as any;
        const solicitanteId = request.headers['x-user-id'] as string;

        if (!publicationId || !date || !startTime || !endTime || !solicitanteId) {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: 'Faltan campos obligatorios para crear la reserva' }
            });
        }

        const newReservation = await prisma.reservation.create({
            data: {
                publicationId,
                solicitanteId,
                date,
                startTime,
                endTime,
                status: ReservationStatus.pending
            }
        });

        return reply.status(201).send({
            message: 'Reserva solicitada exitosamente',
            data: newReservation
        });
    } catch (error) {
        console.error("ERROR EN RESERVAS:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error interno al intentar crear la reserva' }
        });
    }
};

// GET /api/v1/reservations/mine -> Obtener las reservas que se hayan solicitado (reservas del solicitante)
export const getMyReservations = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' }
            });
        }

        const myReservations = await prisma.reservation.findMany({
            where: { solicitanteId: userId },
            include: {
                publication: {
                    select: {
                        title: true,
                        city: true,
                        imageUrl: true
                    }
                }
            },
            orderBy: { date: 'asc' }
        });

        return reply.status(200).send({ data: myReservations });
    } catch (error) {
        console.error("ERROR OBTENIENDO RESERVAS:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al obtener las reservas' }
        });
    }
};

// PATCH /api/v1/reservations/:id/status -> Aceptar o rechazar una reserva
export const updateReservationStatus = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id } = request.params as { id: string };
        const { status } = request.body as { status: ReservationStatus };
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' }
            });
        }

        const existingReservation = await prisma.reservation.findUnique({
            where: { id },
            include: { publication: true }
        });

        if (!existingReservation) {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'La reserva no existe' }
            });
        }

        if (existingReservation.publication.ownerId !== userId) {
            return reply.status(403).send({
                error: { code: 'FORBIDDEN', message: 'Solo el administrador del recinto puede gestionar esta reserva' }
            });
        }

        if (!Object.values(ReservationStatus).includes(status)) {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: `El estado '${status}' no es válido.` }
            });
        }

        const updatedReservation = await prisma.reservation.update({
            where: { id },
            data: { status }
        });

        return reply.status(200).send({
            message: `Reserva actualizada a estado ${status}`,
            data: updatedReservation
        });

    } catch (error) {
        console.error("ERROR ACTUALIZANDO RESERVA:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al cambiar el estado de la reserva' }
        });
    }
};

// PATCH /api/v1/reservations/:id/cancel -> Cancelar una reserva
export const cancelReservation = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id } = request.params as { id: string };
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' }
            });
        }

        const existingReservation = await prisma.reservation.findUnique({
            where: { id }
        });

        if (!existingReservation) {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'La reserva no existe' }
            });
        }

        if (existingReservation.solicitanteId !== userId) {
            return reply.status(403).send({
                error: { code: 'FORBIDDEN', message: 'No puedes cancelar una reserva que no solicitaste' }
            });
        }

        if (existingReservation.status !== ReservationStatus.pending) {
            return reply.status(400).send({
                error: { code: 'BAD_REQUEST', message: 'Solo puedes cancelar reservas que estén en estado pendiente' }
            });
        }

        const cancelledReservation = await prisma.reservation.update({
            where: { id },
            data: { status: ReservationStatus.cancelled }
        });

        return reply.status(200).send({
            message: 'Reserva cancelada exitosamente',
            data: cancelledReservation
        });

    } catch (error) {
        console.error("ERROR CANCELANDO RESERVA:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al cancelar la reserva' }
        });
    }
};
