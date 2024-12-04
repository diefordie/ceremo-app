import jsonwebtoken from "jsonwebtoken"

const JWT_SECRET_KEY = "lalaldidadiuday yawhh"

export const jwt = {
    sign: (payload) => {
        return jsonwebtoken.sign(
            payload,
            JWT_SECRET_KEY,
        )
    },
    verify: (token) => {
        try {
            return jsonwebtoken.verify(
                token,
                JWT_SECRET_KEY
            )
        } catch (_error) {
            return null
        }
    },
}