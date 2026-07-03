<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../../config/database.php';
include_once '../../Middleware/authorizeLandlord.php';

$database = new Database();
$db = $database->getConnection();

// Authorize caller and require Admin
$caller = ensureLandlordOrAdmin($db, 0);
if (!isset($caller['Role']) || $caller['Role'] !== 'Admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden: Admin only."], JSON_UNESCAPED_UNICODE);
    exit();
}

// Optional filters
$maQL = isset($_GET['MaQL']) ? intval($_GET['MaQL']) : null;
$includeDeleted = isset($_GET['include_deleted']) && ($_GET['include_deleted'] === '1' || $_GET['include_deleted'] === 'true');

try {
    $query = "SELECT Id, TenNha, DiaChi, GiayToPhapLy, MaQL, IsApproved, NgayDuyet, NgaySua, IsDeleted FROM NhaTro WHERE 1=1";
    if ($maQL !== null) {
        $query .= " AND MaQL = :maql";
    }
    if (!$includeDeleted) {
        $query .= " AND IsDeleted = 0";
    }
    $query .= " ORDER BY Id DESC";

    $stmt = $db->prepare($query);
    if ($maQL !== null) {
        $stmt->bindParam(':maql', $maQL, PDO::PARAM_INT);
    }
    $stmt->execute();

    $houses = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $houses[] = [
            'Id' => (int)$row['Id'],
            'TenNha' => $row['TenNha'],
            'DiaChi' => $row['DiaChi'],
            'GiayToPhapLy' => $row['GiayToPhapLy'],
            'MaQL' => (int)$row['MaQL'],
            'IsApproved' => (int)$row['IsApproved'],
            'IsDeleted' => (int)$row['IsDeleted']
        ];
    }

    echo json_encode(["status" => "success", "data" => $houses], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}

?>
