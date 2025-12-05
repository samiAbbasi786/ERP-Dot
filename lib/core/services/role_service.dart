import '../database/database.dart';

enum UserRole {
  admin,
  sales,
  manager,
  inventory,
}

enum UserPermission {
  // Sales
  viewSales,
  manageSales, // Create, Edit, Delete
  
  // Inventory
  viewInventory,
  manageInventory,
  
  // Partners
  viewPartners,
  managePartners,
  
  // Users
  viewUsers,
  manageUsers,
  
  // Reports
  viewReports,
  
  // Settings
  viewSettings,
  manageSettings,
}

class RoleService {
  static UserRole getRoleFromString(String roleStr) {
    try {
      return UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == roleStr.toLowerCase(),
        orElse: () => UserRole.sales, // Default to lowest privilege if unknown
      );
    } catch (_) {
      return UserRole.sales;
    }
  }

  static List<UserPermission> getPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return UserPermission.values; // All permissions
        
      case UserRole.manager:
        return [
          UserPermission.viewSales,
          UserPermission.manageSales,
          UserPermission.viewInventory,
          UserPermission.manageInventory,
          UserPermission.viewPartners,
          UserPermission.managePartners,
          UserPermission.viewReports,
          UserPermission.viewUsers, // Read-only users
        ];
        
      case UserRole.sales:
        return [
          UserPermission.viewSales,
          UserPermission.manageSales,
          UserPermission.viewPartners,
          UserPermission.managePartners,
          UserPermission.viewInventory, // Read-only inventory to check stock
        ];
        
      case UserRole.inventory:
        return [
          UserPermission.viewInventory,
          UserPermission.manageInventory,
          UserPermission.viewPartners,
        ];
    }
  }
}

extension UserPermissionExt on User {
  bool hasPermission(UserPermission permission) {
    final userRole = RoleService.getRoleFromString(role);
    final permissions = RoleService.getPermissionsForRole(userRole);
    return permissions.contains(permission);
  }
  
  bool get isAdmin => RoleService.getRoleFromString(role) == UserRole.admin;
}
