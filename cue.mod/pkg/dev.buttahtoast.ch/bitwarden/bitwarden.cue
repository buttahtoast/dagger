package bitwarden

import (
	"dagger.io/dagger"
	//"dagger.io/dagger/core"

	"universe.dagger.io/docker"
)

#Client: {
	// The sign-in address for the account
	email: dagger.#Secret

	// The email adress associated with the account
	pass: dagger.#Secret

	clientID: dagger.#Secret
	clientSecret: dagger.#Secret

	// item-id

}

// Read a secret by secret reference
#Read: {
	// The 1Password account login credentials
	client: #Client
	itemID: string


	_image: docker.#Pull & {
		source: "flipenergy/bitwarden-cli"
	}

	container: docker.#Run & {
		input: _image.output
        entrypoint: ["/bin/bash", "-c"]
		command: {
			name: "export BW_SESSION=$(bw login $BW_EMAIL $BW_PASS --raw) && bw --session=$BW_SESSION get item $ITEM | jq -r .login.password | tr -d '\n' > /tmp/secret.txt"

		}
		export: files: "/tmp/secret.txt": _

		env: {
			BW_EMAIL:    client.email
			BW_PASS:      client.pass
			BW_CLIENTID: client.clientID
			BW_CLIENTSECRET: client.clientSecret 
			ITEM:  itemID
		}
	}

	password: container.export.files["/tmp/secret.txt"]
}