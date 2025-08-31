-- ValWaste Database Schema
-- Create database
CREATE DATABASE IF NOT EXISTS valwaste_db;
USE valwaste_db;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    profile_image VARCHAR(255),
    token VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Waste collections table
CREATE TABLE waste_collections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    waste_type ENUM('general', 'recyclable', 'organic', 'hazardous', 'electronic') NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    description TEXT,
    scheduled_date DATETIME NOT NULL,
    address TEXT NOT NULL,
    status ENUM('pending', 'scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    notes TEXT,
    completed_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Recycling guides table
CREATE TABLE recycling_guides (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    instructions JSON NOT NULL,
    tips JSON NOT NULL,
    image_url VARCHAR(255),
    is_recyclable BOOLEAN DEFAULT TRUE,
    disposal_method TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Admin users table
CREATE TABLE admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'super_admin') DEFAULT 'admin',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Collection teams table
CREATE TABLE collection_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(255),
    area_coverage TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Collection assignments table
CREATE TABLE collection_assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    collection_id INT NOT NULL,
    team_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('assigned', 'in_progress', 'completed') DEFAULT 'assigned',
    notes TEXT,
    FOREIGN KEY (collection_id) REFERENCES waste_collections(id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES collection_teams(id) ON DELETE CASCADE
);

-- Insert sample data

-- Sample admin user
INSERT INTO admin_users (username, email, password, role) VALUES 
('admin', 'admin@valwaste.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'super_admin');

-- Sample recycling guides
INSERT INTO recycling_guides (title, description, category, instructions, tips, is_recyclable) VALUES 
('Plastic Bottles', 'How to properly recycle plastic bottles', 'Plastic', 
'["Rinse the bottle thoroughly", "Remove the cap and label", "Crush the bottle to save space", "Place in recycling bin"]',
'["Check the recycling number on the bottom", "Only recycle clean bottles", "Don\'t recycle bottles that contained motor oil"]',
TRUE),

('Paper and Cardboard', 'Recycling paper and cardboard materials', 'Paper',
'["Remove any plastic or metal attachments", "Flatten cardboard boxes", "Keep paper dry and clean", "Separate by type if required"]',
'["Don\'t recycle greasy pizza boxes", "Shred sensitive documents before recycling", "Remove staples and paper clips"]',
TRUE),

('Glass Containers', 'Proper glass recycling guidelines', 'Glass',
'["Rinse thoroughly", "Remove lids and caps", "Don\'t break the glass", "Separate by color if required"]',
'["Don\'t recycle broken glass", "Check if your area accepts all glass types", "Remove labels if possible"]',
TRUE),

('Electronic Waste', 'How to dispose of electronic waste safely', 'Electronics',
'["Remove batteries", "Wipe personal data", "Find certified e-waste recycler", "Don\'t throw in regular trash"]',
'["Many electronics stores offer recycling programs", "Check for manufacturer take-back programs", "Consider donating working electronics"]',
FALSE),

('Batteries', 'Safe battery disposal methods', 'Hazardous',
'["Don\'t throw in regular trash", "Find battery recycling drop-off", "Tape terminals of lithium batteries", "Store in cool, dry place"]',
'["Many stores accept used batteries", "Check for local battery recycling events", "Never incinerate batteries"]',
FALSE);

-- Sample collection team
INSERT INTO collection_teams (name, contact_person, phone, email, area_coverage) VALUES 
('Green Team Alpha', 'John Smith', '+1234567890', 'john@greenteam.com', 'Downtown Area, North District'),
('Eco Warriors', 'Sarah Johnson', '+1234567891', 'sarah@ecowarriors.com', 'South District, West Suburbs');

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_token ON users(token);
CREATE INDEX idx_collections_user_id ON waste_collections(user_id);
CREATE INDEX idx_collections_status ON waste_collections(status);
CREATE INDEX idx_collections_scheduled_date ON waste_collections(scheduled_date);
CREATE INDEX idx_guides_category ON recycling_guides(category);
CREATE INDEX idx_assignments_collection_id ON collection_assignments(collection_id);
CREATE INDEX idx_assignments_team_id ON collection_assignments(team_id);
