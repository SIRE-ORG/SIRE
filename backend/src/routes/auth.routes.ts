import type { FastifyInstance } from 'fastify';
import { registerGuest, updateAccountStatus, getMe } from '../controllers/auth.controller.js';

export async function authRoutes(app: FastifyInstance) {
    app.post('/register-guest', registerGuest);
    app.patch('/account-status', updateAccountStatus);
    app.get('/me', getMe);
}