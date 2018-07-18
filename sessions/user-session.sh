#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2007-2018 ANSSI. All Rights Reserved.

MINAVAIL=32768
MSGNOAVAIL="Vous ne disposez pas d'un espace libre suffisant dans votre partition utilisateur.

Une session temporaire a été ouverte avec des paramètres par défaut, afin de vous permettre de 
libérer de l'espace. Le comportement normal sera rétabli dès lors que 32Mo d'espace libre seront 
disponibles dans votre partition.

La session temporaire utilise /tmp (système de fichiers temporaire en mémoire) comme dossier 
personnel. Les fichiers stockés dans ce dossier seront perdus à la fermeture de session. 
Votre partition utilisateur habituelle reste accessible sous le chemin /home/user.

Attention : utilisez de préférence l'action \"Supprimer\", plutôt que \"Mettre à la corbeille\",
pour supprimer les fichiers, ou pensez à vider la corbeille.

"
TITLENOAVAIL="Espace disque insuffisant"

USERNAME=`whoami`

if test -z $USERNAME; then
	echo "User name empty"
	exit 1
fi
if test "$USERNAME" == "root"; then
	echo "Root is not allowed to login as user"
	exit 1
else
	HOME=/home/user
fi

SESSION_TYPE=""
for f in "/etc/admin/rm-session-type" "${HOME}/.clip/rm-session-type"; do
	if [[ -f "${f}" ]]; then
		_session="$(cat "${f}")"
		case "${_session}" in
			xfce)
				SESSION_TYPE="xfce"
				;;
			kde)	
				SESSION_TYPE="kde"
				;;
			*)
				echo "Invalid session type ${_session}" >&2
				;;
		esac
	fi
done
if [[ "${SESSION_TYPE}" == "xfce" ]]; then
	[[ -x "/usr/local/bin/startxfce4" ]] || SESSION_TYPE="kde"
fi
if [[ -z "${SESSION_TYPE}" ]]; then
	if [[ -x "/usr/local/bin/startxfce4" ]]; then
		SESSION_TYPE="xfce"
	else
		SESSION_TYPE="kde"
	fi
fi

echo "Session type: ${SESSION_TYPE}"

export HOME
export USERNAME

AVAILABLE="$(df /home/user | awk -vhome="${HOME}" '$6 == home {print $4}')"
if [[ ${AVAILABLE} -lt ${MINAVAIL} ]]; then
	logger -p local0.warning "${USERNAME} home only has ${AVAILABLE}k free space, activating failsafe"
	export HOME=/tmp
	export RM_FAILSAFE="yes"
	export KDE_FAILSAFE=1
fi


source /usr/local/etc/rm-env

# Update user data
mkdir -p /home/user/.clip
clip-update-user-data 1>/home/user/.clip/user-data-update.log 2>&1

# Set default printer
PRINTER="$(lpstat -d | cut -d ' ' -f 4)"
export PRINTER="${PRINTER# }"

XClip 1>/dev/null 2>/dev/null &

if [[ -n "${RM_FAILSAFE}" ]]; then
	sleep 5
	export LC_ALL="fr_FR.UTF-8"
	export LANG="fr_FR.UTF-8"
	kdialog --title "${TITLENOAVAIL}" --error "${MSGNOAVAIL}" &
fi	

echo "User-session : done"
