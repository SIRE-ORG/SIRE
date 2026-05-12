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