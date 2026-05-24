import type { FastifyRequest, FastifyReply } from 'fastify';
import { PrismaClient, AccountStatus } from '@prisma/client';

const prisma = new PrismaClient();

// POST /api/v1/auth/register-guest
export const registerGuest = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const { id, email, name, phone } = request.body as any;

        if (!id || !email) {
            return reply.status(400).send({
                error: {
                    code: 'VALIDATION_ERROR', message: 'El id de Supabase y el email son obligatorios'
                }
            });
        }

        const newProfile = await prisma.profile.create({
            data: {
                id, //Se guarda el mismo ID que genero Supabase
                email,
                name,
                phone,
                accountStatus: AccountStatus.guest
            }
        });

        return reply.status(201).send({ data: newProfile });
    } catch (error) {
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al registrar el usuario' }
        });
    }
};

// PATCH /api/v1/auth/account-status
export const updateAccountStatus = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(400).send({
                error: { code: 'MISSING_CREDENTIALS', message: 'Se requiere identificar el header x-user-id' }
            });
        }

        //El contrato exige que el endpoint actualice a ACTIVE
        const updateProfile = await prisma.profile.update({
            where: { id: userId },
            data: { accountStatus: AccountStatus.active }
        });

        return reply.status(200).send({ data: updateProfile });
    } catch (error) {
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al actualizar el estado de la cuenta' }
        });
    }
};

//GET /api/v1/auth/me
export const getMe = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
        const userId = request.headers['x-user-id'] as string;

        if (!userId) {
            return reply.status(400).send({
                error: { code: 'MISSING_CREDENTIALS', message: 'Se requiere identificar el header x-user-id' }
            });
        }

        const profile = await prisma.profile.findUnique({
            where: { id: userId }
        });

        if (!profile) {
            return reply.status(404).send({
                error: { code: 'NOT_FOUND', message: 'Perfil no encontrado' }
            });
        }

        return reply.status(200).send({ data: profile });
    } catch (error) {
        return reply.status(500).send({
            error: { code: 'INTERNAL_SERVER_ERROR', message: 'Error al obtener el perfil del usuario' }
        });
    }
};