import type { FastifyRequest, FastifyReply } from 'fastify';
import * as UserService from '../services/user.service.js';

export const getProfiles = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const profiles = await UserService.getAllProfiles();
        return reply.send(profiles);
    } catch (error) {
        console.error("ERROR DE PRISMA:", error);

        return reply.status(500).send({ error: 'Error al conectar con la base de datos' });
    }
};

export const updateMyProfile = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'AUTH_UNAUTHORIZED', message: 'Request a endpoint protegido con token inválido o expirado' }
            });
        }

        const data = request.body as {
            name?: string | null;
            phone?: string | null;
            avatarUrl?: string | null;
        };

        const updatedProfile = await UserService.updateProfile(userId, data);

        return reply.status(200).send({ data: updatedProfile });

    } catch (error: any) {
        console.error("ERROR DE PRISMA:", error);

        if (error.code === 'P2025') {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'Perfil no encontrado' }
            });
        }

        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al actualizar el perfil del usuario' }
        });
    }
};