import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAdminsPage extends StatelessWidget {
  const ManageAdminsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Admins"),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("role", isEqualTo: "admin")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final admins = snapshot.data!.docs;

          if (admins.isEmpty) {
            return const Center(child: Text("No admins found."));
          }

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final email = admin["email"];
              final createdAt = admin["createdAt"]?.toDate();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Colors.blue),
                  title: Text(email),
                  subtitle: Text(
                    "Created: ${createdAt != null ? createdAt.toString() : 'N/A'}",
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final currentUserId =
                          FirebaseAuth.instance.currentUser!.uid;

                      if (currentUserId == admin.id) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ You cannot modify yourself!"),
                          ),
                        );
                        return;
                      }

                      if (value == "downgrade") {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(admin.id)
                            .update({"role": "student"});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("⬇️ $email downgraded to Student")),
                        );
                      } else if (value == "delete") {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(admin.id)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("🗑️ Deleted $email")),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "downgrade",
                        child: Text("Downgrade to Student"),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete Admin"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
