const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Client } = require('pg');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Database connection
const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

// Connect to database
client.connect()
    .then(() => console.log('✓ Connected to PostgreSQL database'))
    .catch(err => {
        console.error('✗ Database connection error:', err);
        process.exit(1);
    });

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: '3-Tier Application API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            users: '/api/users',
            user_detail: '/api/users/:id',
            create_user: 'POST /api/users',
            update_user: 'PUT /api/users/:id',
            delete_user: 'DELETE /api/users/:id',
            stats: '/api/stats'
        }
    });
});

// Get all users
app.get('/api/users', async (req, res) => {
    try {
        const result = await client.query('SELECT * FROM users ORDER BY created_at DESC LIMIT 100');
        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// Get single user by ID
app.get('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await client.query('SELECT * FROM users WHERE id = $1', [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        
        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// Create new user
app.post('/api/users', async (req, res) => {
    try {
        const { name, email, phone } = req.body;
        
        // Validation
        if (!name || !email) {
            return res.status(400).json({
                success: false,
                error: 'Name and email are required'
            });
        }
        
        const id = uuidv4();
        const query = 'INSERT INTO users (id, name, email, phone, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING *';
        const result = await client.query(query, [id, name, email, phone || null]);
        
        res.status(201).json({
            success: true,
            message: 'User created successfully',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// Update user
app.put('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, email, phone } = req.body;
        
        const query = 'UPDATE users SET name = COALESCE($1, name), email = COALESCE($2, email), phone = COALESCE($3, phone), updated_at = NOW() WHERE id = $4 RETURNING *';
        const result = await client.query(query, [name || null, email || null, phone || null, id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        
        res.json({
            success: true,
            message: 'User updated successfully',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// Delete user
app.delete('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await client.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        
        res.json({
            success: true,
            message: 'User deleted successfully',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// Get application statistics
app.get('/api/stats', async (req, res) => {
    try {
        const result = await client.query(`
            SELECT 
                COUNT(*) as total_users,
                COUNT(CASE WHEN created_at > NOW() - INTERVAL '24 hours' THEN 1 END) as users_today,
                COUNT(CASE WHEN phone IS NOT NULL THEN 1 END) as users_with_phone
            FROM users
        `);
        
        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        success: false,
        error: err.message || 'Internal server error'
    });
});

// Start server
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
    console.log(`✓ Server running on port ${PORT}`);
    console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing gracefully...');
    server.close(() => {
        console.log('Server closed');
        client.end();
        process.exit(0);
    });
});

module.exports = app;
