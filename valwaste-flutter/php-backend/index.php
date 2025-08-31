<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = 'localhost';
$dbname = 'valwaste_db';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit();
}

// Get request method and path
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = str_replace('/api', '', $path);

// Simple routing
switch ($path) {
    case '/login':
        if ($method === 'POST') {
            handleLogin($pdo);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
        break;
        
    case '/register':
        if ($method === 'POST') {
            handleRegister($pdo);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
        break;
        
    case '/user/profile':
        if ($method === 'GET') {
            handleGetProfile($pdo);
        } elseif ($method === 'PUT') {
            handleUpdateProfile($pdo);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
        break;
        
    case '/waste-collections':
        if ($method === 'GET') {
            handleGetCollections($pdo);
        } elseif ($method === 'POST') {
            handleCreateCollection($pdo);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
        break;
        
    case (preg_match('/^\/waste-collections\/(\d+)$/', $path, $matches) ? true : false):
        $id = $matches[1];
        if ($method === 'PUT') {
            handleUpdateCollection($pdo, $id);
        } elseif ($method === 'DELETE') {
            handleDeleteCollection($pdo, $id);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
        break;
        
    case '/recycling-guides':
        if ($method === 'GET') {
            handleGetGuides($pdo);
        } else {
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
        }
        break;
        
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
        break;
}

function handleLogin($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['email']) || !isset($data['password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Email and password are required']);
        return;
    }
    
    $email = $data['email'];
    $password = $data['password'];
    
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user && password_verify($password, $user['password'])) {
        $token = bin2hex(random_bytes(32));
        
        // Store token in database (simplified)
        $stmt = $pdo->prepare("UPDATE users SET token = ? WHERE id = ?");
        $stmt->execute([$token, $user['id']]);
        
        unset($user['password']);
        $user['token'] = $token;
        
        echo json_encode([
            'success' => true,
            'token' => $token,
            'user' => $user
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid credentials']);
    }
}

function handleRegister($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['name']) || !isset($data['email']) || !isset($data['password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Name, email, and password are required']);
        return;
    }
    
    $name = $data['name'];
    $email = $data['email'];
    $password = password_hash($data['password'], PASSWORD_DEFAULT);
    $phone = $data['phone'] ?? '';
    $address = $data['address'] ?? '';
    
    // Check if email already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode(['error' => 'Email already exists']);
        return;
    }
    
    $stmt = $pdo->prepare("INSERT INTO users (name, email, password, phone, address, created_at) VALUES (?, ?, ?, ?, ?, NOW())");
    $stmt->execute([$name, $email, $password, $phone, $address]);
    
    $userId = $pdo->lastInsertId();
    $token = bin2hex(random_bytes(32));
    
    $stmt = $pdo->prepare("UPDATE users SET token = ? WHERE id = ?");
    $stmt->execute([$token, $userId]);
    
    echo json_encode([
        'success' => true,
        'token' => $token,
        'user' => [
            'id' => $userId,
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'address' => $address,
            'created_at' => date('Y-m-d H:i:s')
        ]
    ]);
}

function handleGetProfile($pdo) {
    $token = getAuthToken();
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        return;
    }
    
    $stmt = $pdo->prepare("SELECT id, name, email, phone, address, created_at FROM users WHERE token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        echo json_encode(['user' => $user]);
    } else {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token']);
    }
}

function handleUpdateProfile($pdo) {
    $token = getAuthToken();
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $stmt = $pdo->prepare("UPDATE users SET name = ?, phone = ?, address = ? WHERE token = ?");
    $stmt->execute([$data['name'], $data['phone'], $data['address'], $token]);
    
    $stmt = $pdo->prepare("SELECT id, name, email, phone, address, created_at FROM users WHERE token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode(['user' => $user]);
}

function handleGetCollections($pdo) {
    $token = getAuthToken();
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        return;
    }
    
    $stmt = $pdo->prepare("SELECT wc.* FROM waste_collections wc JOIN users u ON wc.user_id = u.id WHERE u.token = ? ORDER BY wc.created_at DESC");
    $stmt->execute([$token]);
    $collections = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode(['collections' => $collections]);
}

function handleCreateCollection($pdo) {
    $token = getAuthToken();
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $stmt = $pdo->prepare("SELECT id FROM users WHERE token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $stmt = $pdo->prepare("INSERT INTO waste_collections (user_id, waste_type, quantity, unit, description, scheduled_date, address, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', NOW())");
    $stmt->execute([
        $user['id'],
        $data['waste_type'],
        $data['quantity'],
        $data['unit'],
        $data['description'],
        $data['scheduled_date'],
        $data['address']
    ]);
    
    $collectionId = $pdo->lastInsertId();
    
    $stmt = $pdo->prepare("SELECT * FROM waste_collections WHERE id = ?");
    $stmt->execute([$collectionId]);
    $collection = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode(['collection' => $collection]);
}

function handleUpdateCollection($pdo, $id) {
    $token = getAuthToken();
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $stmt = $pdo->prepare("UPDATE waste_collections SET waste_type = ?, quantity = ?, unit = ?, description = ?, scheduled_date = ?, address = ? WHERE id = ? AND user_id = (SELECT id FROM users WHERE token = ?)");
    $stmt->execute([
        $data['waste_type'],
        $data['quantity'],
        $data['unit'],
        $data['description'],
        $data['scheduled_date'],
        $data['address'],
        $id,
        $token
    ]);
    
    $stmt = $pdo->prepare("SELECT * FROM waste_collections WHERE id = ?");
    $stmt->execute([$id]);
    $collection = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode(['collection' => $collection]);
}

function handleDeleteCollection($pdo, $id) {
    $token = getAuthToken();
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        return;
    }
    
    $stmt = $pdo->prepare("DELETE FROM waste_collections WHERE id = ? AND user_id = (SELECT id FROM users WHERE token = ?)");
    $stmt->execute([$id, $token]);
    
    echo json_encode(['success' => true]);
}

function handleGetGuides($pdo) {
    $query = $_GET['q'] ?? '';
    
    if ($query) {
        $stmt = $pdo->prepare("SELECT * FROM recycling_guides WHERE title LIKE ? OR description LIKE ?");
        $searchTerm = "%$query%";
        $stmt->execute([$searchTerm, $searchTerm]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM recycling_guides");
        $stmt->execute();
    }
    
    $guides = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['guides' => $guides]);
}

function getAuthToken() {
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        return str_replace('Bearer ', '', $headers['Authorization']);
    }
    return null;
}
?>
