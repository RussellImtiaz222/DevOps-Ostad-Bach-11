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
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true
}));
app.use(express.json());
app.use(morgan('combined'));

// Database connection
const client = new Client({
    host: process.env.DB_HOST || 'localhost',
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
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Root API endpoint
app.get('/api', (req, res) => {
    res.json({
        name: 'BMI Health Tracker API',
        version: '1.0.0',
        description: 'Track and manage BMI measurements',
        endpoints: {
            health: 'GET /api/health',
            measurements: 'GET /api/measurements',
            create_measurement: 'POST /api/measurements',
            get_measurement: 'GET /api/measurements/:id',
            update_measurement: 'PUT /api/measurements/:id',
            delete_measurement: 'DELETE /api/measurements/:id',
            stats: 'GET /api/measurements/stats/summary'
        }
    });
});

// Get all measurements
app.get('/api/measurements', async (req, res) => {
    try {
        const result = await client.query(
            'SELECT * FROM measurements ORDER BY measurement_date DESC LIMIT 100'
        );
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

// Get single measurement by ID
app.get('/api/measurements/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await client.query(
            'SELECT * FROM measurements WHERE id = $1',
            [id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Measurement not found'
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

// Create new measurement
app.post('/api/measurements', async (req, res) => {
    try {
        const { height, weight, measurement_date, notes } = req.body;
        
        // Validation
        if (!height || !weight) {
            return res.status(400).json({
                success: false,
                error: 'Height and weight are required'
            });
        }
        
        // Calculate BMI
        const bmi = weight / (height * height);
        
        const id = uuidv4();
        const date = measurement_date || new Date().toISOString().split('T')[0];
        
        const query = `
            INSERT INTO measurements (id, height, weight, bmi, measurement_date, notes, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, NOW())
            RETURNING *
        `;
        
        const result = await client.query(query, [
            id,
            parseFloat(height),
            parseFloat(weight),
            parseFloat(bmi.toFixed(2)),
            date,
            notes || null
        ]);
        
        res.status(201).json({
            success: true,
            message: 'Measurement created successfully',
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

// Update measurement
app.put('/api/measurements/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { height, weight, measurement_date, notes } = req.body;
        
        // Calculate BMI if height or weight provided
        let bmi = null;
        if (height && weight) {
            bmi = weight / (height * height);
        }
        
        const query = `
            UPDATE measurements
            SET height = COALESCE($1, height),
                weight = COALESCE($2, weight),
                bmi = COALESCE($3, bmi),
                measurement_date = COALESCE($4, measurement_date),
                notes = COALESCE($5, notes),
                updated_at = NOW()
            WHERE id = $6
            RETURNING *
        `;
        
        const result = await client.query(query, [
            height ? parseFloat(height) : null,
            weight ? parseFloat(weight) : null,
            bmi ? parseFloat(bmi.toFixed(2)) : null,
            measurement_date || null,
            notes || null,
            id
        ]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Measurement not found'
            });
        }
        
        res.json({
            success: true,
            message: 'Measurement updated successfully',
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

// Delete measurement
app.delete('/api/measurements/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await client.query(
            'DELETE FROM measurements WHERE id = $1 RETURNING *',
            [id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Measurement not found'
            });
        }
        
        res.json({
            success: true,
            message: 'Measurement deleted successfully',
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

// Get measurements statistics
app.get('/api/measurements/stats/summary', async (req, res) => {
    try {
        const result = await client.query(`
            SELECT 
                COUNT(*) as total_measurements,
                ROUND(AVG(bmi)::numeric, 2) as avg_bmi,
                ROUND(MIN(bmi)::numeric, 2) as min_bmi,
                ROUND(MAX(bmi)::numeric, 2) as max_bmi,
                ROUND(AVG(weight)::numeric, 2) as avg_weight,
                COUNT(CASE WHEN measurement_date > NOW() - INTERVAL '7 days' THEN 1 END) as measurements_this_week
            FROM measurements
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
    console.log(`✓ BMI Health Tracker API running on port ${PORT}`);
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
