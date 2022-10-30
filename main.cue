package helm

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpha/kubernetes/helm"
  	"dev.buttahtoast.ch/bitwarden"
    //"universe.dagger.io/docker"
    "universe.dagger.io/alpine"

)
image: alpine.#Build
dagger.#Plan & {

	client: {
		filesystem: "./infra": read: contents: dagger.#FS
		env: {
            KUBECONFIG: string
            BW_EMAIL:    dagger.#Secret
            BW_PASS:      dagger.#Secret
            BW_CLIENTID: dagger.#Secret
            BW_CLIENTSECRET: dagger.#Secret
        }
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
	}
	_opCreds: bitwarden.#Client & {
		email:   client.env.BW_EMAIL
		pass:     client.env.BW_PASS
        clientID: client.env.BW_CLIENTID
        clientSecret: client.env.BW_CLIENTSECRET
	}

	actions: {
		// mySecret: bitwarden.#Read & {
        //    itemID: "55afddb4-3811-49cd-ba34-af2a00d25f9c"
        //    client: _opCreds 
		// }
    
        cfDndtoken: bitwarden.#Read & {
            itemID: "acc2cf19-589d-424d-8a02-af3e01583f79"
            client: _opCreds 
        }
        deploy: {

            flux: helm.#Upgrade & {
                kubeconfig:    client.commands.kubeconfig.stdout
                name:          "flux2"
                repo:          "https://fluxcd-community.github.io/helm-charts"
                chart:         "flux2"
                version:       "1.6.1"
                namespace:     "buttah-system"
                atomic:        true
                install:       true
                cleanupOnFail: true
                debug:         true
                force:         true
                wait:          true
                timeout:       "2m"
            }   


            infra: helm.#Upgrade & {
                kubeconfig:    client.commands.kubeconfig.stdout
                workspace:     client.filesystem."./infra".read.contents
                name:          "infra"
                repo:          "./"
                chart:         "infra"
                version:       "0.1.0"
                namespace:     "buttah-system"
                atomic:        true
                install:       true
                cleanupOnFail: true
                debug:         true
                force:         true
                wait:          true
                timeout:       "2m"
                env: {
                    cfDndToken: cfDndtoken.password
                }
                flags: ["--skip-crds", "--dependency-update", "--create-namespace"]
                setString: #"""
                    master.podAnnotations.n=1
                    certManager.cfButtahtoast.apiToken=$cfDndToken
                    """#
            }
        }
    }
}
