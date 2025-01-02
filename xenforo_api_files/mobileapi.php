<?php

/*****
 * Xenforo Mobile API
 * 
 * Description:
 * This API provides endpoints for interacting with XenForo features, 
 * including blocking users and reporting posts.
 * 
 * Author: Matthew Drennan
 * Date: 1/1/2025
 * 
 *****/

$fileDir = '../';  // Relative path to the XenForo root
require('src/XF.php');
XF::start($fileDir);
$app = XF::setupApp('XF\Pub\App');
$app->start();

// Database connection
$db = \XF::db();

// Get action parameter
$action = $_GET['action'] ?? null;

// Block User API
if ($action === 'block_user') {
    $blockerUserId = (int)($_GET['blocker_id'] ?? 0); // The user doing the blocking
    $blockedUserId = (int)($_GET['blocked_id'] ?? 0); // The user being blocked

    // Validate inputs
    if (!$blockerUserId || !$blockedUserId) {
        http_response_code(400);
        echo json_encode(['error' => 'Both blocker_id and blocked_id are required']);
        exit();
    }

    if ($blockerUserId === $blockedUserId) {
        http_response_code(400);
        echo json_encode(['error' => 'You cannot block yourself']);
        exit();
    }

    try {
        // Fetch blocker and blocked users
        $blocker = \XF::finder('XF:User')->where('user_id', $blockerUserId)->fetchOne();
        $blocked = \XF::finder('XF:User')->where('user_id', $blockedUserId)->fetchOne();

        if (!$blocker || !$blocked) {
            http_response_code(404);  // Not Found
            echo json_encode(['error' => 'One or both users not found']);
            exit();
        }

        // Check if already ignored
        $ignored = $db->fetchOne("
            SELECT ignored_user_id 
            FROM xf_user_ignored 
            WHERE user_id = ? AND ignored_user_id = ?
        ", [$blockerUserId, $blockedUserId]);

        if ($ignored) {
            echo json_encode(['message' => 'User is already blocked']);
            exit();
        }

        // Add user to ignore list using entity system
        $ignoredEntity = $app->em()->create('XF:UserIgnored');
        $ignoredEntity->user_id = $blockerUserId;
        $ignoredEntity->ignored_user_id = $blockedUserId;
        $ignoredEntity->save(); // Automatically triggers rebuildIgnoredCache()

        echo json_encode(['message' => 'User blocked successfully']);
    } catch (\Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to block user', 'details' => $e->getMessage()]);
    }
    exit();
}

if ($action === 'report_post') {
    $postId = (int)($_GET['post_id'] ?? 0);
    $message = $_GET['message'] ?? 'No reason provided.';
    $reporterUserId = (int)($_GET['reporter_id'] ?? 0); // Custom reporter user ID

    if (!$postId) {
        http_response_code(400);
        echo json_encode(['error' => 'Post ID is required']);
        exit();
    }

    try {
        // Retrieve the post entity
        $post = $app->em()->find('XF:Post', $postId); // Correct method to fetch entity

        // Check if the post exists
        if (!$post) {
            http_response_code(404);  // Not Found
            echo json_encode(['error' => 'Post not found']);
            exit();
        }

        // Retrieve the custom user entity as the reporter
        $reporter = $app->em()->find('XF:User', $reporterUserId);
        if (!$reporter) {
            http_response_code(404);  // Not Found
            echo json_encode(['error' => 'Reporter user not found']);
            exit();
        }

        // Temporarily impersonate the reporter user
        \XF::setVisitor($reporter); // Set the visitor to the custom user

        // Create the report
        $creator = $app->service('XF:Report\Creator', 'post', $post);
        $creator->setMessage($message);

        if (!$creator->validate()) {
            http_response_code(400);
            echo json_encode(['error' => 'Validation failed']);
            exit();
        }

        $report = $creator->save();
        if ($report) {
            echo json_encode(['message' => 'Post reported successfully', 'report_id' => $report->report_id]);
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to report post']);
        }
    } catch (\Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to report post', 'details' => $e->getMessage()]);
    } finally {
        // Reset visitor to original user (important to avoid side effects)
        \XF::setVisitor(\XF::visitor());
    }
    exit();
}

// Default response if no valid action is provided
http_response_code(400);
echo json_encode(['error' => 'Invalid action specified']);
exit();

?>