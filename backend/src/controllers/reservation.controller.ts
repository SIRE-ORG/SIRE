import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient, ReservationStatus } from '@prisma/client';

const prisma = new PrismaClient();

// POST /api/v1/reservations -> Crear solicitud de reserva
export const createReservation = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { publicationId, date, startTime, endTime } = request.body as any;
        const solicitanteId = request.headers['x-user-id'] as string;

        // 1. Validaciones básicas
        if (!publicationId || !date || !startTime || !endTime || !solicitanteId) {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: 'Faltan campos obligatorios para crear la reserva' }
            });
        }

        // 2. Crear la reserva usando el Enum correcto de Prisma
        const newReservation = await prisma.reservation.create({
            data: {
                publicationId,
                solicitanteId,
                date,
                startTime,
                endTime,
                status: ReservationStatus.PENDING
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