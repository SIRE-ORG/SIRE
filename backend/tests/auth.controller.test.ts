import { describe, it, expect, vi, beforeEach } from 'vitest';
import { registerGuest, updateAccountStatus, getMe } from '../src/controllers/auth.controller';

const prismaMock = vi.hoisted(() => ({
    profile: {
        create: vi.fn(),
        update: vi.fn(),
        findUnique: vi.fn(),
    }
}));

vi.mock('@prisma/client', () => ({
    PrismaClient: class { constructor() { return prismaMock; } },
    AccountStatus: { guest: 'guest', active: 'active' }
}));

describe('Módulo 1: Autenticación y Perfiles', () => {
    let mockRequest: any;
    let mockReply: any;

    beforeEach(() => {
        vi.clearAllMocks();
        mockRequest = { body: {}, headers: {} };
        mockReply = {
            status: vi.fn().mockReturnThis(),
            send: vi.fn()
        };
    });

    //PRUEBA registerGuest
    it('Registro: Debería crear un perfil invitado y retornar 201', async () => {
        mockRequest.body = { id: 'uuid-supabase', email: 'test@test.com', name: 'Test', phone: '123' };
        prismaMock.profile.create.mockResolvedValue({ id: 'uuid-supabase', email: 'test@test.com' });

        await registerGuest(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(201);
    });

    it('Registro: Debería fallar con 400 si falta el id o el email', async () => {
        mockRequest.body = { name: 'Falta ID y Email' }; // Body incompleto

        await registerGuest(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    //PRUEBA updateAccountStatus
    it('Estado Cuenta: Debería actualizar a ACTIVE y retornar 200', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        prismaMock.profile.update.mockResolvedValue({ id: 'uuid-supabase', accountStatus: 'active' });

        await updateAccountStatus(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    //PRUEBA getMe
    it('Perfil: Debería retornar el perfil del usuario con estado 200', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-supabase';
        prismaMock.profile.findUnique.mockResolvedValue({ id: 'uuid-supabase', name: 'Test' });

        await getMe(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(200);
    });

    it('Perfil: Debería fallar con 404 si el perfil no existe en Prisma', async () => {
        mockRequest.headers['x-user-id'] = 'uuid-fantasma';
        prismaMock.profile.findUnique.mockResolvedValue(null); // No se encontró

        await getMe(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(404);
    });

    //PRUEBA seguridad global
    it('Seguridad Global: Debería fallar con 400 si no se envía x-user-id en las rutas protegidas', async () => {
        mockRequest.headers = {}; // Sin header de seguridad

        await getMe(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);

        await updateAccountStatus(mockRequest, mockReply);
        expect(mockReply.status).toHaveBeenCalledWith(400);
    });

    //MÓDULO 4: EXCEPCIONES GLOBALES
    it('Excepciones: Debería retornar 500 si Prisma falla en el registro', async () => {
        mockRequest.body = { id: 'uuid-error', email: 'error@test.com' };
        prismaMock.profile.create.mockRejectedValue(new Error('Prisma Network Error'));

        await registerGuest(mockRequest, mockReply);

        expect(mockReply.status).toHaveBeenCalledWith(500);
    });
});