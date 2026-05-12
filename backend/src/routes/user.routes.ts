import type { FastifyInstance } from 'fastify';
import { getProfiles } from '../controllers/user.controller.js';

export async function userRoutes(fastify: FastifyInstance) {
    fastify.get('/profiles', getProfiles);
}