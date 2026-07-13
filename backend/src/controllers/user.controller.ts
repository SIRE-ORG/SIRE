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

        const body = request.body as {
            name?: string | null;
            phone?: string | null;
            avatarUrl?: string | null;
            [key: string]: unknown;
        };

        // Whitelist: solo estos campos son editables por el propio usuario.
        // Cualquier otro campo (ej. accountStatus, email) se ignora para evitar
        // escalada de privilegios o bypass del flujo de activacion por OTP.
        const data: { name?: string | null; phone?: string | null; avatarUrl?: string | null } = {};
        if (body.name !== undefined) data.name = body.name;
        if (body.phone !== undefined) data.phone = body.phone;
        if (body.avatarUrl !== undefined) data.avatarUrl = body.avatarUrl;

        if (Object.keys(data).length === 0) {
            return reply.status(400).send({
                error: { code: 'VALIDATION_ERROR', message: 'Debes enviar al menos un campo editable (name, phone o avatarUrl)' }
            });
        }

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
