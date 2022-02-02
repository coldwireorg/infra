job "website" {
  datacenters = ["dc1", "coldwire"]
  type = "service"

  group "website" {
    count = 1
    network {
      port "website_http" {}
    }

    restart {
      attempts = 2
      interval = "30m"

      delay = "15s"

      mode = "fail"
    }

    task "website" {
      driver = "docker"

      # The "config" stanza specifies the driver configuration, which is passed
      # directly to the driver to start the task. The details of configurations
      # are specific to each driver, so please see specific driver
      # documentation for more information.
      config {
        image = "coldwireorg/website:v0.0.3"
        ports = ["website_http"]
      }

      env {
        SERVER_PORT = NOMAD_PORT_website_http 
      }
    }
  }
}
