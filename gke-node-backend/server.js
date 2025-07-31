const express = require('express');
const path = require('path');
const { Spanner } = require('@google-cloud/spanner');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

const app = express();
const port = process.env.PORT || 8080;
const projectId = process.env.GCP_PROJECT_ID;
const spannerConnectionSecretId = process.env.SPANNER_CONNECTION_STRING_SECRET_ID;

// Serve static files (React frontend)
app.use(express.static(path.join(__dirname, 'public')));

let spannerDatabase;

async function initializeSpanner() {
    try {
        if (!projectId || !spannerConnectionSecretId) {
            throw new Error('GCP_PROJECT_ID or SPANNER_CONNECTION_STRING_SECRET_ID env vars not set.');
        }

        const secretManagerClient = new SecretManagerServiceClient();
        const secretName = `projects/${projectId}/secrets/${spannerConnectionSecretId}/versions/latest`;
        const [version] = await secretManagerClient.accessSecretVersion({ name: secretName });
        const spannerDatabasePath = version.payload.data.toString('utf8');

        console.log(`Retrieved Spanner connection path: ${spannerDatabasePath}`);

        const parts = spannerDatabasePath.split('/');
        const instanceId = parts[parts.indexOf('instances') + 1];
        const databaseId = parts[parts.indexOf('databases') + 1];

        const spanner = new Spanner({ projectId });
        const instance = spanner.instance(instanceId);
        spannerDatabase = instance.database(databaseId);

        // Optional: Test connection
        await spannerDatabase.run({ sql: 'SELECT 1' });
        console.log('Successfully connected to Google Spanner.');

    } catch (error) {
        console.error('Failed to initialize Spanner connection:', error);
        // Depending on your error handling strategy, you might exit or retry.
        process.exit(1); // Exit if critical DB connection fails
    }
}

// Example API endpoint: Fetch users from Spanner
app.get('/api/users', async (req, res) => {
    try {
        if (!spannerDatabase) {
            return res.status(500).send('Database not initialized.');
        }
        const [rows] = await spannerDatabase.run({ sql: 'SELECT UserId, Name, Email FROM Users' });
        const users = rows.map(row => row.toJSON());
        res.json(users);
    } catch (error) {
        console.error('Error fetching users from Spanner:', error);
        res.status(500).send('Error fetching users.');
    }
});

// Serve React app for any other routes
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
    initializeSpanner();
});
