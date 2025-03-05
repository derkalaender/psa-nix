#!/usr/bin/env nix
#!nix shell nixpkgs#python3 nixpkgs#openssl --command python

import base64
import csv
import os
import secrets
import shlex
import subprocess
import textwrap
from dataclasses import dataclass

# Constants
CSV_FILE = "./psa_users.csv"
OUTPUT_FOLDER = "./output/psa_users"
PSA_GID = 1000
BASE_DN = "dc=team06,dc=psa,dc=cit,dc=tum,dc=de"


@dataclass
class User:
    name: str
    username: str
    uid: int


# Checks if the input file exists and creates output folder
def init():
    if not os.path.isfile(CSV_FILE):
        print(f"Error: {CSV_FILE} not found")
        exit(1)

    os.makedirs(OUTPUT_FOLDER, exist_ok=True)


# Generates the string for a new user entry in LDIF format
def generate_ldif_str(user: User, hashedPassword: str, binb64Certificate) -> str:
    return textwrap.dedent(
        f"""
        # Entry for {user.name} ({user.username})
        dn: uid={user.username},ou=users,{BASE_DN}
        objectClass: posixAccount
        objectClass: account
        objectClass: pkiUser
        uid: {user.username}
        cn: {user.name}
        uidNumber: {user.uid}
        gidNumber: {PSA_GID}
        homeDirectory: /home/{user.username}
        loginShell: /bin/bash
        userPassword: {hashedPassword}
        userCertificate;binary:: {binb64Certificate}
        description: User account for {user.name} ({user.username})
        """
    ).strip()


# Hashes the password using slappasswd
def hash_password(password: str) -> str:
    cmd = shlex.split(f"slappasswd -h {{SSHA}} -s {password}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()


# Converts the certificate at the given path to binary and base64 encodes it
def binb64_certificate(certPath: str) -> str:
    cmd = shlex.split(f"openssl x509 -in {certPath} -outform DER")
    result = subprocess.run(cmd, capture_output=True)
    return base64.b64encode(result.stdout).decode("utf-8")


# Creates the LDIF file for a user
def create_ldif(user: User, password: str):
    ldifPath = f"{OUTPUT_FOLDER}/{user.username}.ldif"

    if os.path.exists(ldifPath):
        print(f"{user.username}: Using existing LDIF")
        return

    print(f"{user.username}: Generating new LDIF")
    ldif = generate_ldif_str(
        user,
        hash_password(password),
        binb64_certificate(f"{OUTPUT_FOLDER}/{user.username}.crt"),
    )

    with open(ldifPath, "w") as ldif_file:
        ldif_file.write(ldif)


# Creates the password for a user and returns it in cleartext
def create_password(user: User) -> str:
    passwordPath = f"{OUTPUT_FOLDER}/{user.username}.password"

    if os.path.exists(passwordPath):
        print(f"{user.username}: Using existing password")

        with open(passwordPath, "r") as password_file:
            return password_file.read().strip()

    print(f"{user.username}: Generating new password")
    password = secrets.token_urlsafe(24)

    with open(passwordPath, "w") as password_file:
        password_file.write(password)
        password_file.write("\n")

    return password


# Creates a self-signed certificate for a user and returns its public key in PEM format
def create_certificate(user: User):
    certPath = f"{OUTPUT_FOLDER}/{user.username}.crt"
    keyPath = f"{OUTPUT_FOLDER}/{user.username}.key"

    if os.path.exists(certPath) and os.path.exists(keyPath):
        print(f"{user.username}: Using existing certificate")
        return

    # delete existing files
    for file in [certPath, keyPath]:
        if os.path.exists(file):
            os.remove(file)

    print(f"{user.username}: Generating new certificate")
    cmd = shlex.split(
        f"openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout {keyPath} -out {certPath} -subj '/C=DE/ST=Bayern/L=München/O=UwU Corp./OU=users/CN={user.username}/emailAddress={user.username}@psa-team06.cit.tum.de'"
    )
    subprocess.run(cmd)


# Reads the CSV user file
def read_csv() -> list[User]:
    users = []
    with open(CSV_FILE, "r") as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # Skip header row
        for row in reader:
            # Remove surrounding whitespace
            name, username, uid = (field.strip() for field in row)
            users.append(User(name, username, int(uid)))
    return users


# Processes each user one by one, creating the necessary files
def process_users(users: list[User]):
    for user in users:
        print(f"Processing user: {user.name} ({user.username})")
        password = create_password(user)
        create_certificate(user)
        create_ldif(user, password)


# Populates LDAP server with the generated LDIF files
def populate_ldap(users: list[User]):
    overrideAll = False

    for user in users:
        # Check if user exists
        cmd = shlex.split(
            f"sudo ldapsearch -Y EXTERNAL -H ldapi:// -Q -LLL -b {BASE_DN} uid={user.username} dn"
        )
        result = subprocess.run(cmd, capture_output=True, text=True)
        if "dn" in result.stdout:
            if not overrideAll:
                choice = input(
                    f"{user.username} already exists in LDAP. Override? ([y]/a/n): "
                )

                if choice == "a":
                    overrideAll = True
                elif choice == "n":
                    continue

            # Delete user from LDAP
            print(f"Deleting {user.username} from LDAP...")
            cmd = shlex.split(
                f"sudo ldapdelete -Y EXTERNAL -H ldapi:// -Q uid={user.username},ou=users,{BASE_DN}"
            )
            subprocess.run(cmd)

        # Add user to LDAP
        print(f"Adding {user.username} to LDAP...")
        ldifPath = f"{OUTPUT_FOLDER}/{user.username}.ldif"
        cmd = shlex.split(
            f"sudo ldapmodify -ac -Y EXTERNAL -H ldapi:// -Q -f {ldifPath}"
        )
        subprocess.run(cmd)


# Write the password to the users' home directory
# This function uses sudo for access to the user's home directory
def write_password_home(user: list[User]):
    overrideAll = False

    for user in users:
        passwordPath = f"{OUTPUT_FOLDER}/{user.username}.password"
        homePath = f"/oldhome/{user.username}"
        homePasswordPath = f"{homePath}/LDAP_PASSWORD"

        # Check if password file exists
        cmd = shlex.split(f"sudo test -f {homePasswordPath}")
        result = subprocess.run(cmd)
        if result.returncode == 0:
            if not overrideAll:
                choice = input(
                    f"{user.username}: Password file already exists. Override? ([y]/a/n): "
                )

                if choice == "a":
                    overrideAll = True
                elif choice == "n":
                    continue

            # Delete password file
            print(f"{user.username}: Deleting password file...")
            cmd = shlex.split(f"sudo rm {homePasswordPath}")
            subprocess.run(cmd)

        # Write password to file
        print(f"{user.username}: Writing password to file...")
        cmd = shlex.split(f"sudo cp {passwordPath} {homePasswordPath}")
        subprocess.run(cmd)

        # Change owner of password file
        print(f"{user.username}: Changing owner of password file...")
        cmd = shlex.split(f"sudo chown {user.username}:{PSA_GID} {homePasswordPath}")
        subprocess.run(cmd)

        # Change permissions of password file
        print(f"{user.username}: Changing permissions of password file...")
        cmd = shlex.split(f"sudo chmod 400 {homePasswordPath}")
        subprocess.run(cmd)


# Write the certificate key to the users' home directory
# This function uses sudo for access to the user's home directory
def write_key_home(user: list[User]):
    overrideAll = False

    for user in users:
        keyPath = f"{OUTPUT_FOLDER}/{user.username}.key"
        homePath = f"/oldhome/{user.username}"
        homeKeyPath = f"{homePath}/LDAP_CERTIFICATE.key"

        # Check if certificate key file exists
        cmd = shlex.split(f"sudo test -f {homeKeyPath}")
        result = subprocess.run(cmd)
        if result.returncode == 0:
            if not overrideAll:
                choice = input(
                    f"{user.username}: Certificate key file already exists. Override? ([y]/a/n): "
                )

                if choice == "a":
                    overrideAll = True
                elif choice == "n":
                    continue

            # Delete certificate key file
            print(f"{user.username}: Deleting certificate key file...")
            cmd = shlex.split(f"sudo rm {homeKeyPath}")
            subprocess.run(cmd)

        # Write certificate key to file
        print(f"{user.username}: Writing certificate key to file...")
        cmd = shlex.split(f"sudo cp {keyPath} {homeKeyPath}")
        subprocess.run(cmd)

        # Change owner of certificate key file
        print(f"{user.username}: Changing owner of certificate key file...")
        cmd = shlex.split(f"sudo chown {user.username}:{PSA_GID} {homeKeyPath}")
        subprocess.run(cmd)

        # Change permissions of certificate key file
        print(f"{user.username}: Changing permissions of certificate key file...")
        cmd = shlex.split(f"sudo chmod 400 {homeKeyPath}")
        subprocess.run(cmd)


if __name__ == "__main__":
    init()

    print(f"Reading user information from {CSV_FILE}...")
    users = read_csv()

    print("Processing users...")
    process_users(users)

    choice = (
        input("Do you want to continue and populate the LDAP server? ([y]/n): ")
        .strip()
        .lower()
    )
    if choice != "n":
        print("Continuing and populating the LDAP server...")
        populate_ldap(users)

    choice = (
        input(
            "Do you want to write the password to the users' home directories? ([y]/n): "
        )
        .strip()
        .lower()
    )
    if choice != "n":
        print("Writing the password to the users' home directories...")
        write_password_home(users)

    choice = (
        input(
            "Do you want to write the certificate key to the users' home directories? ([y]/n): "
        )
        .strip()
        .lower()
    )
    if choice != "n":
        print("Writing the certificate key to the users' home directories...")
        write_key_home(users)

    print("Done!")
