import prisma from "../repositories/prisma.repository.js";

export const getAllProfiles = async () => {
    return await prisma.profile.findMany();
};