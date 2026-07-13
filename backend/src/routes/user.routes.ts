import type { FastifyInstance } from 'fastify';
import { getProfiles, updateMyProfile } from '../controllers/user.controller.js';

export async function userRoutes(fastify: FastifyInstance) {
    fastify.get('/profiles', getProfiles);
    fastify.put('/me', updateMyProfile);
}