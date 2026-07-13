import type { FastifyRequest, FastifyReply } from 'fastify';
import * as UserService from '../services/user.service.js';
import prisma from '../repositories/prisma.repository.js';

export const getProfiles = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const profiles = await UserService.getAllProfiles();
        return reply.send(profiles);
    } catch (error) {
        console.error("ERROR DE PRISMA:", error);

        return reply.status(500).send({ error: 'Error al conectar con la base de datos' });
    }
};

// PUT /api/v1/users/me -> Editar el perfil propio. Autoriza por x-user-id
// (mismo patrón que reservation.controller). Solo pisa los campos presentes
// en el body: name/phone/avatarUrl ausentes no se sobreescriben con null.
// Responde el mismo shape que GET /auth/me ({ data: profile }).
export const updateMyProfile = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(401).send({
                error: { code: 'AUTH_UNAUTHORIZED', message: 'Request a endpoint protegido con token inválido o expirado' }
            });
        }

        const existing = await prisma.profile.findUnique({ where: { id: userId } });

        if (!existing) {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'Perfil no encontrado' }
            });
        }

        const { name, phone, avatarUrl } = request.body as {
            name?: string;
            phone?: string;
            avatarUrl?: string;
        };

        const data: { name?: string; phone?: string; avatarUrl?: string } = {};
        if (name !== undefined) data.name = name;
        if (phone !== undefined) data.phone = phone;
        if (avatarUrl !== undefined) data.avatarUrl = avatarUrl;

        const updatedProfile = await prisma.profile.update({
            where: { id: userId },
            data
        });

        return reply.status(200).send({ data: updatedProfile });
    } catch (error) {
        console.error("ERROR ACTUALIZANDO PERFIL:", error);
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al actualizar el perfil' }
        });
    }
};