// Netlify Function to submit GitHub issues
// This keeps the GitHub token secure on the server side

exports.handler = async (event) => {
    // CORS headers for all responses
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Content-Type': 'application/json'
    };

    // Handle preflight OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }

    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
        return {
            statusCode: 405,
            headers,
            body: JSON.stringify({ error: 'Method Not Allowed' })
        };
    }

    // Parse the request body
    let data;
    try {
        data = JSON.parse(event.body);
    } catch (error) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Invalid JSON' })
        };
    }

    const { title, body, labels } = data;

    // Validate required fields
    if (!title || !body) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Title and body are required' })
        };
    }

    // Get GitHub token from environment variable
    const githubToken = process.env.GITHUB_TOKEN;
    if (!githubToken) {
        console.error('GITHUB_TOKEN environment variable is not set');
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: 'Server configuration error' })
        };
    }

    // Create GitHub issue
    try {
        const response = await fetch('https://api.github.com/repos/rabah-khalek/zetanotes/issues', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `token ${githubToken}`,
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'ZetaNotes-Feedback-Form'
            },
            body: JSON.stringify({
                title,
                body,
                labels: labels || ['user-submitted']
            })
        });

        const responseData = await response.json();

        if (!response.ok) {
            console.error('GitHub API error:', responseData);
            return {
                statusCode: response.status,
                headers,
                body: JSON.stringify({
                    error: 'Failed to create issue',
                    details: responseData.message
                })
            };
        }

        // Return success response
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                issue_url: responseData.html_url,
                issue_number: responseData.number
            })
        };
    } catch (error) {
        console.error('Error creating GitHub issue:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};
