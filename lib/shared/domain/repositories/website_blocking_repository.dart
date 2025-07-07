import '../entities/blocked_website.dart';

abstract class WebsiteBlockingRepository {
  Future<List<BlockedWebsite>> getBlockedWebsites();
  Future<BlockedWebsite> getBlockedWebsite(String id);
  Future<void> addBlockedWebsite(BlockedWebsite website);
  Future<void> updateBlockedWebsite(BlockedWebsite website);
  Future<void> removeBlockedWebsite(String id);
  Future<void> blockWebsite(String domain);
  Future<void> unblockWebsite(String domain);
  Future<bool> isWebsiteBlocked(String domain);
  Future<void> startWebsiteBlocking(List<String> blockedDomains);
  Future<void> stopWebsiteBlocking();
  Future<bool> requestVpnPermission();
}