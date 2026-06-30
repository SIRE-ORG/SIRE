import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient, ReservationStatus } from '@prisma/client';

const prisma = new PrismaClient();

// Helper: valida que un string de fecha "YYYY-MM-DD" sea parseable
function parseDate(dateStr: string): Date {
    const d = new Date(dateStr);
    if (Number.isNaN(d.getTime)) {
        throw new Error(`Formato de fecha inválido: ${dateStr}`);
    }
    return d;
}

// POST /api/v1/reservations -> Crear solicitud de reserva
export const createReservation = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const solicitanteId = request.headers['x-user-id'] as string;

        if (!solicitanteId) {
            return reply.status(401).send({
                error: { code: 'AUTH_UNAUTHORIZED', message: 'Request a endpoint protegido con token inválido o expirado' }
            });
        }

        const { publicationId, date, startTime, endTime } = request.body as any;

        if (!publicationId || !date || !startTime || !endTime) {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: 'Faltan campos obligatorios para crear la reserva' }
            });
        }

        let parsedDate: Date;
        try {
            parsedDate = parseDate(date);
        } catch {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: `Formato de fecha inválido: ${date}. Use YYYY-MM-DD.` }
            });
        }

        // 1. Obtener datos de la publicación para saber quién es el dueño
        const publication = await prisma.publication.findUnique({
            where: { id: publicationId },
            select: { ownerId: true, title: true }
        });

        if (!publication) {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'La publicación a reservar no existe' }
            });
        }

        const newReservation = await prisma.reservation.create({
            data: {
                publicationId,
                solicitanteId,
                date: parsedDate,
                startTime,
                endTime,
                status: ReservationStatus.pending
            }
        });

        // 3. Crear la notificación on-event (RF-06.1)
        await prisma.notification.create({
            data: {
                userId: publication.ownerId, // Destinatario: dueño de la publicación 
                type: 'new_reservation',
                title: '¡Nueva reserva solicitada!',
                body: `Han solicitado una reserva para "${publication.title}" el ${date} de ${startTime} a ${endTime}.`, // Compuesto en el backend 
                reservationId: newReservation.id
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

// GET /api/v1/reservations/received -> Reservas sobre publicaciones del usuario (vista publisher)
export const getReceivedReservations = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' }
            });
        }

        const receivedReservations = await prisma.reservation.findMany({
            where: { publication: { ownerId: userId } },
            include: {
                publication: {
                    select: {
                        title: true,
                        city: true,
                        imageUrl: true
                    }
                },
                solicitante: {
                    select: {
                        name: true,
                        email: true,
                        phone: true
                    }
                }
            },
            orderBy: { date: 'asc' }
        });

        return reply.status(200).send({ data: receivedReservations });
    } catch (error) {
        console.error("ERROR OBTENIENDO RESERVAS RECIBIDAS:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al obtener las reservas recibidas' }
        });
    }
};

// GET /api/v1/reservations/:id -> Detalle de una reserva (agnóstico al rol)
export const getReservationById = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id } = request.params as { id: string };
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'UNAUTHORIZED', message: 'Se requiere el header x-user-id' }
            });
        }

        const reservation = await prisma.reservation.findUnique({
            where: { id },
            include: {
                publication: {
                    select: {
                        title: true,
                        city: true,
                        imageUrl: true,
                        ownerId: true // necesario para autorizar al publisher (abajo)
                    }
                }
            }
        });

        if (!reservation) {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'La reserva no existe' }
            });
        }

        // Autorización: solicitante dueño o ownerId de la publicación
        if (reservation.solicitanteId !== userId && reservation.publication.ownerId !== userId) {
            return reply.status(403).send({
                error: { code: 'FORBIDDEN', message: 'No tienes permisos para ver esta reserva' }
            });
        }

        return reply.status(200).send({ data: reservation });
    } catch (error) {
        console.error("ERROR OBTENIENDO DETALLE DE RESERVA:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al obtener el detalle de la reserva' }
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

        const estadoTexto: Record<string, string> = {
            completed: 'Aceptada',
            rejected: 'Rechazada',
            cancelled: 'Cancelada',
            pending: 'Pendiente',
            failed: 'Fallida'
        };
        const estadoAmigable = estadoTexto[status] || status;

        await prisma.notification.create({
            data: {
                userId: existingReservation.solicitanteId, // Destinatario: el solicitante 
                type: 'status_updated',
                title: 'Actualización de tu reserva',
                body: `Tu solicitud para "${existingReservation.publication.title}" ha cambiado a estado: ${estadoAmigable}.`, // 
                reservationId: updatedReservation.id
            }
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
            where: { id },
            include: { publication: true }
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

        await prisma.notification.create({
            data: {
                userId: existingReservation.publication.ownerId, // Destinatario: dueño de la publicación 
                type: 'reservation_cancelled',
                title: 'Reserva cancelada',
                body: `El solicitante ha cancelado su reserva para "${existingReservation.publication.title}".`, // 
                reservationId: cancelledReservation.id
            }
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
