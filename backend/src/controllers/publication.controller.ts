import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const ALLOWED_CATEGORIES = ['DEPORTE', 'EVENTOS', 'RECREACION', 'OTROS'];

// GET /api/v1/publications -> El feed público con filtro opcional de región
export const getPublications = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { region } = request.query as { region?: string };

        const publications = await prisma.publication.findMany({
            where: region ? { region: { equals: region, mode: 'insensitive' } } : {},
            include: {
                owner: {
                    select: { name: true, phone: true }
                }
            }
        });

        return reply.status(200).send({ data: publications });
    } catch (error) {
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al obtener las publicaciones' }
        });
    }
};

// GET /api/v1/publications/mine -> Publicaciones del usuario autenticado
export const getMyPublications = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'AUTH_UNAUTHORIZED', message: 'Request a endpoint protegido con token inválido o expirado' }
            });
        }

        const myPublications = await prisma.publication.findMany({
            where: { ownerId: userId }
        });

        return reply.status(200).send({ data: myPublications });
    } catch (error) {
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al obtener tus publicaciones' }
        });
    }
};

// POST /api/v1/publications -> Crear publicación
export const createPublication = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { title, description, category, imageUrl, region, city, availability, ownerId } = request.body as any;

        if (!title || !category || !region || !availability || !ownerId) {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: 'Faltan campos obligatorios para crear la publicación' }
            });
        }

        if (!ALLOWED_CATEGORIES.includes(category)) {
            return reply.status(400).send({
                error: {
                    code: 'VALIDATION_ERROR',
                    message: `La categoría '${category}' no es válida. Valores permitidos: ${ALLOWED_CATEGORIES.join(', ')}`
                }
            });
        }

        const userProfile = await prisma.profile.findUnique({
            where: { id: ownerId }
        });

        if (userProfile?.accountStatus !== 'active') {
            return reply.status(403).send({
                error: {
                    code: 'FORBIDDEN',
                    message: 'Debes tener una cuenta activa registrada para crear publicaciones en la plataforma.'
                }
            });
        }

        const newPublication = await prisma.publication.create({
            data: {
                title,
                description,
                category,
                imageUrl,
                region,
                city,
                availability,
                ownerId
            }
        });

        return reply.status(201).send({
            message: 'Publicación creada exitosamente',
            data: newPublication
        });
    } catch (error) {
        console.error(error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error interno al intentar crear la publicación' }
        });
    }
};

// GET /api/v1/publications/:id -> Obtener el detalle de una sola publicación
export const getPublicationById = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id } = request.params as { id: string };

        const publication = await prisma.publication.findUnique({
            where: { id },
            include: {
                owner: { select: { name: true, avatarUrl: true } }
            }
        });

        if (!publication) {
            return reply.status(404).send({ error: { code: 'NOT_FOUND', message: 'Publicación no encontrada' } });
        }

        return reply.status(200).send({ data: publication });
    } catch (error) {
        return reply.status(500).send({ error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error interno' } });
    }
};

// PUT /api/v1/publications/:id -> Editar una cancha
export const updatePublication = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id } = request.params as { id: string };
        const userId = request.headers['x-user-id'] as string;
        const updateData = request.body as any;

        if (!userId) return reply.status(401).send({ error: { code: 'UNAUTHORIZED', message: 'Falta header' } });

        const existing = await prisma.publication.findUnique({ where: { id } });
        if (!existing) return reply.status(404).send({ error: { code: 'NOT_FOUND', message: 'No existe' } });
        if (existing.ownerId !== userId) return reply.status(403).send({ error: { code: 'FORBIDDEN', message: 'No eres el dueño' } });

        const updatedPublication = await prisma.publication.update({
            where: { id },
            data: updateData
        });

        return reply.status(200).send({ message: 'Cancha actualizada', data: updatedPublication });
    } catch (error) {
        return reply.status(500).send({ error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al actualizar' } });
    }
};

// DELETE /api/v1/publications/:id -> Borrar una cancha
export const deletePublication = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id } = request.params as { id: string };
        const userId = request.headers['x-user-id'] as string;

        if (!userId) return reply.status(401).send({ error: { code: 'UNAUTHORIZED', message: 'Falta header' } });

        const existing = await prisma.publication.findUnique({ where: { id } });
        if (!existing) return reply.status(404).send({ error: { code: 'NOT_FOUND', message: 'No existe' } });
        if (existing.ownerId !== userId) return reply.status(403).send({ error: { code: 'FORBIDDEN', message: 'No eres el dueño' } });

        await prisma.publication.delete({ where: { id } });

        return reply.status(200).send({ message: 'Publicación eliminada correctamente' });
    } catch (error) {
        return reply.status(500).send({ error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al eliminar' } });
    }
};