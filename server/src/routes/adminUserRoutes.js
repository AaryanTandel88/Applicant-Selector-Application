/**
 * @file adminUserRoutes.js
 * @description Admin user management router for RAC DRDO Adaptive Interview System (Part 7A).
 * Strict RBAC: Accessible ONLY by authenticated ADMIN role.
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../db/prismaClient');
const { requireAuth } = require('../middleware/authMiddleware');

const router = express.Router();

/**
 * GET /api/admin/users
 * Lists all registered user accounts with roles and active status.
 */
router.get('/', requireAuth(['ADMIN']), async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        username: true,
        role: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return res.status(200).json(users);
  } catch (error) {
    return res.status(500).json({
      error: 'Failed to retrieve user accounts.',
      details: error.message,
    });
  }
});

/**
 * POST /api/admin/users
 * Creates a new examiner or admin account with hashed password.
 */
router.post('/', requireAuth(['ADMIN']), async (req, res) => {
  try {
    const { name, username, password, role = 'EXAMINER' } = req.body || {};

    if (!name || !username || !password) {
      return res.status(400).json({
        error: 'name, username, and password are required fields.',
      });
    }

    if (!['ADMIN', 'EXAMINER'].includes(role)) {
      return res.status(400).json({
        error: 'Role must be either ADMIN or EXAMINER.',
      });
    }

    const cleanUsername = String(username).trim().toLowerCase();

    // Check duplicate username
    const existing = await prisma.user.findUnique({
      where: { username: cleanUsername },
    });

    if (existing) {
      return res.status(409).json({
        error: `User account with username "${cleanUsername}" already exists.`,
      });
    }

    // Hash password with bcryptjs
    const passwordHash = bcrypt.hashSync(password, 10);

    const newUser = await prisma.user.create({
      data: {
        name: String(name).trim(),
        username: cleanUsername,
        passwordHash,
        role,
        isActive: true,
      },
      select: {
        id: true,
        name: true,
        username: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    });

    // Record audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        action: 'CREATE_USER',
        entityType: 'User',
        entityId: newUser.id,
        details: { username: newUser.username, role: newUser.role },
      },
    });

    return res.status(201).json({
      message: 'User account created successfully.',
      user: newUser,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Failed to create user account.',
      details: error.message,
    });
  }
});

/**
 * PATCH /api/admin/users/:id/toggle
 * Activates or deactivates an existing user account.
 */
router.patch('/:id/toggle', requireAuth(['ADMIN']), async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      return res.status(404).json({ error: `User with ID "${id}" not found.` });
    }

    // Prevent deactivating own account
    if (user.id === req.user.id) {
      return res.status(400).json({ error: 'Cannot deactivate your own active session.' });
    }

    const updated = await prisma.user.update({
      where: { id },
      data: { isActive: !user.isActive },
      select: {
        id: true,
        name: true,
        username: true,
        role: true,
        isActive: true,
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        action: 'TOGGLE_USER_STATUS',
        entityType: 'User',
        entityId: updated.id,
        details: { username: updated.username, isActive: updated.isActive },
      },
    });

    return res.status(200).json({
      message: `User account is now ${updated.isActive ? 'active' : 'deactivated'}.`,
      user: updated,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Failed to toggle user status.',
      details: error.message,
    });
  }
});

module.exports = router;

