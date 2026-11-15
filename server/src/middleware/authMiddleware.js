/**
 * @file authMiddleware.js
 * @description JWT authentication and role-based access control (RBAC) middleware for RAC DRDO system.
 * Part 7A: Gating examiner and admin routes behind signed JWTs in httpOnly cookies or Bearer headers.
 */

const jwt = require('jsonwebtoken');
const prisma = require('../db/prismaClient');
const { JWT_SECRET } = require('../config/authConfig');

/**
 * Extracts and verifies JWT from httpOnly cookie 'rac_token' or 'Authorization: Bearer <token>' header.
 * Attaches authenticated user object to req.user.
 *
 * @param {string[]} [allowedRoles=[]] - Array of required roles (e.g. ['ADMIN']). If empty, permits any authenticated role.
 * @returns {Function} Express middleware handler.
 */
function requireAuth(allowedRoles = []) {
  return async (req, res, next) => {
    try {
      let token = null;

      // 1. Extract from httpOnly cookie
      if (req.cookies && req.cookies.rac_token) {
        token = req.cookies.rac_token;
      }

      // 2. Fallback to Authorization header
      if (!token && req.headers && req.headers.authorization) {
        const parts = req.headers.authorization.split(' ');
        if (parts.length === 2 && parts[0] === 'Bearer') {
          token = parts[1];
        }
      }

      if (!token) {
        return res.status(401).json({
          error: 'Authentication required. No valid token found.',
        });
      }

      // 3. Verify JWT signature & expiration
      let decoded;
      try {
        decoded = jwt.verify(token, JWT_SECRET);
      } catch (jwtErr) {
        return res.status(401).json({
          error: 'Session expired or invalid authentication token.',
        });
      }

      // 4. Fetch active user from database
      const user = await prisma.user.findUnique({
        where: { id: decoded.id },
        select: {
          id: true,
          name: true,
          username: true,
          role: true,
          isActive: true,
        },
      });

      if (!user || !user.isActive) {
        return res.status(401).json({
          error: 'User account not found or deactivated.',
        });
      }

      // 5. Enforce RBAC roles
      if (Array.isArray(allowedRoles) && allowedRoles.length > 0) {
        if (!allowedRoles.includes(user.role)) {
          return res.status(403).json({
            error: `Forbidden: Requires one of [${allowedRoles.join(', ')}] role privileges.`,
          });
        }
      }

      req.user = user;
      next();
    } catch (err) {
      return res.status(500).json({
        error: 'Authentication verification failure.',
        details: err.message,
      });
    }
  };
}

module.exports = {
  requireAuth,
};

