output "cluster_id" {
  value = databricks_cluster.this.id
}

output "cluster_name" {
  value = databricks_cluster.this.cluster_name
}
