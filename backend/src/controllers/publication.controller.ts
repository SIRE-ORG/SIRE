import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// GET: Obtener todas las canchas para el Home de la App
export const getPublications = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const publications = await prisma.publication.findMany({
            //'include' trae los datos del dueño en la misma consulta
            include: {
                owner: {
                    select: { name: true, accountStatus: true, avatarUrl: true }
                }
            }
        });
        return reply.status(200).send({
            message: 'Canchas obtenidas con éxito',
            data: publications
        });
    } catch (error) {
        console.error('Error en getPublications:', error);
        return reply.status(500).send({ error: 'Error al cargar las publicaciones' });
    }
};

